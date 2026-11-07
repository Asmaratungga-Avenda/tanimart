<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class LatestOrders extends TableWidget
{
    protected static ?int $sort = 2;

    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Pesanan Terbaru (Backend TokoTani)';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => Order::query()->latest()->limit(5))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('nama_penerima')
                    ->label('Penerima')
                    ->searchable(),
                TextColumn::make('courier.nama')
                    ->label('Kurir'),
                TextColumn::make('paymentMethod.nama')
                    ->label('Metode Bayar'),
                TextColumn::make('total_harga')
                    ->label('Total')
                    ->money('IDR', locale: 'id'),
                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (?string $state): string => match ($state) {
                        'menunggu_pembayaran' => 'warning',
                        'diproses' => 'info',
                        'dikirim' => 'primary',
                        'selesai' => 'success',
                        'dibatalkan' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('tanggal_antar')
                    ->label('Tgl Antar')
                    ->date(),
                TextColumn::make('created_at')
                    ->label('Waktu Pesan')
                    ->dateTime(),
            ])
            ->recordActions([
                Action::make('detail')
                    ->label('Detail')
                    ->url(fn (Order $record): string => OrderResource::getUrl('edit', ['record' => $record])),
            ]);
    }
}
