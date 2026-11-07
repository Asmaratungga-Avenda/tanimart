<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Courier;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nama_penerima')
                    ->label('Nama Penerima')
                    ->required()
                    ->maxLength(255),
                Textarea::make('alamat_penerima')
                    ->label('Alamat Penerima')
                    ->required()
                    ->columnSpanFull(),
                Select::make('kurir_id')
                    ->label('Kurir')
                    ->relationship('courier', 'nama', fn ($query) => $query->where('aktif', true))
                    ->required()
                    ->searchable()
                    ->preload()
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        if ($state) {
                            $courier = Courier::find($state);
                            if ($courier) {
                                $set('ongkir', $courier->tarif);
                                $subtotal = (int) ($get('subtotal') ?: 0);
                                $set('total_harga', $subtotal + $courier->tarif);
                            }
                        }
                    }),
                Select::make('payment_method_id')
                    ->label('Metode Pembayaran')
                    ->relationship('paymentMethod', 'nama', fn ($query) => $query->where('aktif', true))
                    ->required()
                    ->searchable()
                    ->preload(),
                DatePicker::make('tanggal_antar')
                    ->label('Tanggal Pengantaran')
                    ->required(),
                Select::make('status')
                    ->label('Status Pesanan')
                    ->options([
                        'menunggu_pembayaran' => 'Menunggu Pembayaran',
                        'diproses' => 'Diproses',
                        'dikirim' => 'Dikirim',
                        'selesai' => 'Selesai',
                        'dibatalkan' => 'Dibatalkan',
                    ])
                    ->default('menunggu_pembayaran')
                    ->required(),
                TextInput::make('subtotal')
                    ->label('Subtotal')
                    ->numeric()
                    ->prefix('Rp')
                    ->required()
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        $ongkir = (int) ($get('ongkir') ?: 0);
                        $set('total_harga', ((int) $state) + $ongkir);
                    }),
                TextInput::make('ongkir')
                    ->label('Ongkos Kirim')
                    ->numeric()
                    ->prefix('Rp')
                    ->required()
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        $subtotal = (int) ($get('subtotal') ?: 0);
                        $set('total_harga', $subtotal + ((int) $state));
                    }),
                TextInput::make('total_harga')
                    ->label('Total Harga')
                    ->numeric()
                    ->prefix('Rp')
                    ->required(),
                TextInput::make('idempotency_key')
                    ->label('Idempotency Key')
                    ->disabled()
                    ->columnSpanFull(),
            ]);
    }
}
